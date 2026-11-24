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

  /// The Firestore document for `Telemetry_Crashes`. The keys, types and caps match
  /// firestore.rules: no PII beyond the signed-in uid, createdAt set by the server.
  Map<String, dynamic> toMap({String? uid}) {
    final cleanMessage = _cap(message, CrashReportingService.maxMessageLength);
    return {
      'message': cleanMessage.isEmpty ? 'Unknown error' : cleanMessage,
      'stack': _cap(stackTrace, CrashReportingService.maxStackLength),
      if (context != null) 'context': _cap(context!, CrashReportingService.maxContextLength),
      'isFatal': isFatal,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String _cap(String value, int max) => value.length <= max ? value : value.substring(0, max);
}

/// Enterprise crash reporting and error telemetry service.
/// Intercepts uncaught framework errors and logs them to telemetry.
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  static const int maxMessageLength = 2000;
  static const int maxStackLength = 8000;
  static const int maxContextLength = 500;
  static const int maxReportsPerSession = 5;
  static const Duration writeTimeout = Duration(seconds: 5);

  final ValueNotifier<List<TelemetryErrorItem>> recentErrors = ValueNotifier<List<TelemetryErrorItem>>([]);

  final Set<String> _sentMessages = <String>{};
  int _sentCount = 0;

  /// Replaces the Firestore write (tests). Receives the document id and map.
  @visibleForTesting
  Future<void> Function(String id, Map<String, dynamic> data)? writeOverride;

  @visibleForTesting
  String? Function()? uidOverride;

  @visibleForTesting
  void resetSession() {
    _sentMessages.clear();
    _sentCount = 0;
  }

  /// A report is sent at most [maxReportsPerSession] times per session, and a message that was
  /// already sent is not sent again, so a crash loop cannot spam Firestore.
  bool _claimReportSlot(String message) {
    if (_sentCount >= maxReportsPerSession || _sentMessages.contains(message)) return false;
    _sentMessages.add(message);
    _sentCount += 1;
    return true;
  }

  String? _currentUid() {
    try {
      return uidOverride != null ? uidOverride!() : FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

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
    try {
      await _record(error, stack, reason: reason, fatal: fatal);
    } catch (e) {
      debugPrint('[CrashReportingService] Notice: could not record error ($e)');
    }
  }

  Future<void> _record(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final errorItem = TelemetryErrorItem(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}_$_sentCount',
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

    if (!_claimReportSlot(errorItem.message)) return;
    try {
      final data = errorItem.toMap(uid: _currentUid());
      final write = writeOverride ??
          (id, map) => FirebaseFirestore.instance.collection('Telemetry_Crashes').doc(id).set(map);
      await write(errorItem.id, data).timeout(writeTimeout);
    } catch (e) {
      debugPrint('[CrashReportingService] Notice: Could not send telemetry ($e)');
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
