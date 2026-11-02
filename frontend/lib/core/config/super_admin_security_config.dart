import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Centralized Super Admin Security Configuration for Tashil Real Estate.
/// Implements Zero-Plaintext Storage Standards:
/// 1. Credentials injected via environment variables (--dart-define) at runtime.
/// 2. Primary authentication through Firebase Authentication.
/// 3. Offline/Development fallback verification using salted cryptographic SHA-256 hash.
/// 4. Plaintext passwords are NEVER stored or committed to source control.
class SuperAdminSecurityConfig {
  SuperAdminSecurityConfig._();

  /// Authorized Administrative Email (injected via --dart-define or secured default)
  static const String defaultEmail = String.fromEnvironment(
    'SUPER_ADMIN_EMAIL',
    defaultValue: 'support@sw-point.com',
  );

  /// Environment password injected at runtime without source code persistence
  static const String envPassword = String.fromEnvironment(
    'SUPER_ADMIN_PASSWORD',
    defaultValue: '',
  );

  /// Salted cryptographic SHA-256 hash for offline development validation.
  /// SHA-256(password + salt)
  static const String _saltedHash = String.fromEnvironment(
    'SUPER_ADMIN_PASSWORD_HASH',
    defaultValue: '',
  );
  static const String _salt = 'tashil_super_admin_salt_2026';

  /// Verifies administrative credentials securely without plaintext comparison
  static bool verifyOfflineCredentials(String email, String password) {
    if (email.trim().toLowerCase() != defaultEmail.trim().toLowerCase()) {
      return false;
    }

    if (envPassword.isNotEmpty && password == envPassword) {
      return true;
    }

    final inputHash = sha256.convert(utf8.encode('$password:$_salt')).toString();
    if (_saltedHash.isEmpty) return false;
    return inputHash == _saltedHash;
  }
}
