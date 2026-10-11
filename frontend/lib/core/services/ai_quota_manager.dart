import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages and enforces daily usage quotas for Google Gemini AI valuations
/// to prevent quota exhaustion and credit overage.
class AiQuotaManager {
  static final AiQuotaManager _instance = AiQuotaManager._internal();
  factory AiQuotaManager() => _instance;
  AiQuotaManager._internal();

  static const int maxVisitorDailyQuota = 3;
  static const int maxRegisteredDailyQuota = 15;

  int _usedToday = 0;
  DateTime _lastResetDate = DateTime.now();

  final ValueNotifier<int> remainingQuotaNotifier = ValueNotifier<int>(maxVisitorDailyQuota);

  /// Checks and resets the quota if a new calendar day has started
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.year != _lastResetDate.year ||
        now.month != _lastResetDate.month ||
        now.day != _lastResetDate.day) {
      _usedToday = 0;
      _lastResetDate = now;
      _updateNotifier();
    }
  }

  /// Returns the maximum allowed daily quota based on auth status
  int get maxDailyQuota {
    try {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      return isLoggedIn ? maxRegisteredDailyQuota : maxVisitorDailyQuota;
    } catch (_) {
      return maxVisitorDailyQuota;
    }
  }

  /// Returns remaining valuations for today
  int get remainingQuota {
    _checkDailyReset();
    final remaining = maxDailyQuota - _usedToday;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if the user has available quota
  bool get hasAvailableQuota {
    return remainingQuota > 0;
  }

  /// Records a successful AI valuation request
  bool recordUsage() {
    _checkDailyReset();
    if (_usedToday < maxDailyQuota) {
      _usedToday++;
      _updateNotifier();
      return true;
    }
    return false;
  }

  void _updateNotifier() {
    remainingQuotaNotifier.value = remainingQuota;
  }
}
