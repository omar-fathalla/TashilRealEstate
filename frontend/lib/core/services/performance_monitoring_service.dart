import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Enterprise performance monitoring service for Tashil Real Estate.
/// Provides zero-latency trace collection, custom metrics, and benchmarking.
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  FirebasePerformance? _performance;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  /// Initializes Firebase Performance Monitoring safely.
  Future<void> initialize() async {
    try {
      _performance = FirebasePerformance.instance;
      await _performance?.setPerformanceCollectionEnabled(true);
      _isAvailable = true;
      debugPrint('[PerformanceMonitoringService] Initialized successfully.');
    } catch (e) {
      _isAvailable = false;
      debugPrint('[PerformanceMonitoringService] Notice: Performance collection running in fallback mode ($e)');
    }
  }

  /// Starts a custom trace with the given [traceName].
  Future<TraceSession?> startTrace(String traceName) async {
    final startTime = DateTime.now();
    Trace? trace;
    if (_isAvailable && _performance != null) {
      try {
        trace = _performance!.newTrace(traceName);
        await trace.start();
      } catch (e) {
        debugPrint('[PerformanceMonitoringService] Could not start Firebase trace $traceName: $e');
      }
    }
    return TraceSession(name: traceName, startTime: startTime, trace: trace);
  }

  /// Runs an asynchronous [action] and measures its duration in milliseconds.
  Future<BenchmarkResult<T>> benchmark<T>(String operationName, Future<T> Function() action) async {
    final trace = await startTrace(operationName);
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;
      await trace?.stop(metrics: {'duration_ms': durationMs});
      return BenchmarkResult<T>(
        operationName: operationName,
        durationMs: durationMs,
        result: result,
        isSuccess: true,
      );
    } catch (e) {
      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;
      await trace?.stop(metrics: {'duration_ms': durationMs, 'error': 1});
      return BenchmarkResult<T>(
        operationName: operationName,
        durationMs: durationMs,
        result: null,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }
}

/// Active trace session wrapper.
class TraceSession {
  final String name;
  final DateTime startTime;
  final Trace? trace;

  TraceSession({required this.name, required this.startTime, this.trace});

  /// Stops the trace and records optional metrics.
  Future<int> stop({Map<String, int>? metrics}) async {
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    if (trace != null) {
      try {
        if (metrics != null) {
          for (final entry in metrics.entries) {
            trace!.setMetric(entry.key, entry.value);
          }
        }
        await trace!.stop();
      } catch (e) {
        debugPrint('[TraceSession] Error stopping trace $name: $e');
      }
    }
    debugPrint('[PerformanceTrace] $name took ${durationMs}ms');
    return durationMs;
  }
}

/// Result of a performance benchmark execution.
class BenchmarkResult<T> {
  final String operationName;
  final int durationMs;
  final T? result;
  final bool isSuccess;
  final String? error;

  BenchmarkResult({
    required this.operationName,
    required this.durationMs,
    this.result,
    required this.isSuccess,
    this.error,
  });
}
