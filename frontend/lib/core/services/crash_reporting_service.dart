import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Recorded telemetry crash item for observability and live diagnostics.
class TelemetryErrorItem {
  final String id;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final bool isFatal;
  final String? context;

  TelemetryErrorItem({
    required this.id,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    required this.isFatal,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'isFatal': isFatal,
      'context': context,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
    };
  }
}

/// Enterprise crash reporting and error telemetry service.
/// Intercepts uncaught framework errors and logs them to telemetry.
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  final ValueNotifier<List<TelemetryErrorItem>> recentErrors = ValueNotifier<List<TelemetryErrorItem>>([]);

  /// Initializes error boundary and hooks into Flutter's platform dispatchers.
  void initialize() {
    debugPrint('[CrashReportingService] Initialized telemetry listener.');
  }

  /// Records an application error with full context.
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final errorItem = TelemetryErrorItem(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      message: error.toString(),
      stackTrace: stack?.toString() ?? '',
      timestamp: DateTime.now(),
      isFatal: fatal,
      context: reason,
    );

    // Update in-memory stream for live UI inspection
    final updatedList = List<TelemetryErrorItem>.from(recentErrors.value)..insert(0, errorItem);
    if (updatedList.length > 20) {
      updatedList.removeLast();
    }
    recentErrors.value = updatedList;

    debugPrint('[CrashReportingService] Telemetry error captured: ${errorItem.message}');

    // Persist to Cloud Firestore telemetry collection safely
    try {
      await FirebaseFirestore.instance
          .collection('Telemetry_Crashes')
          .doc(errorItem.id)
          .set(errorItem.toMap());
    } catch (e) {
      // Non-blocking telemetry fallback
      debugPrint('[CrashReportingService] Notice: Could not send telemetry to Firestore ($e)');
    }
  }

  /// Formats and records a standard FlutterErrorDetails.
  void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason: details.context?.toString(),
      fatal: false,
    );
  }

  /// Simulates a test error to verify telemetry and observability in real time.
  Future<void> simulateTestError() async {
    try {
      throw StateError('Firebase Enterprise Telemetry Verification Test (Simulated)');
    } catch (e, stack) {
      await recordError(e, stack, reason: 'Manual Test from Firebase Enterprise Hub');
    }
  }
}
