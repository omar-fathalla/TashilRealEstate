import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The AI features the `geminiGenerate` Cloud Function accepts. The server decides which of
/// them signed-out visitors may use and how often.
enum GeminiFeature {
  valuation('valuation'),
  geocoding('geocoding'),
  marketIndex('market_index'),
  imageModeration('image_moderation'),
  voiceBroker('voice_broker'),
  semanticSearch('semantic_search'),
  legalAdvisor('legal_advisor'),
  onboarding('onboarding'),
  documentOcr('document_ocr');

  const GeminiFeature(this.wireName);
  final String wireName;
}

typedef GeminiCallable = Future<Object?> Function(Map<String, dynamic> payload);

/// The only way the app talks to Gemini. Requests go to the `geminiGenerate` callable,
/// which holds the API key in Secret Manager; the client never sees a key or a Gemini URL.
///
/// Results come back as an [http.Response] in Gemini's own JSON shape, so callers keep
/// parsing `candidates[0].content.parts`. Failures become non-200 responses, never throws.
class GeminiGateway {
  GeminiGateway._();

  static const String functionName = 'geminiGenerate';

  @visibleForTesting
  static GeminiCallable? callOverride;

  static Future<Object?> _invoke(Map<String, dynamic> payload, Duration timeout) async {
    final override = callOverride;
    if (override != null) return override(payload);
    final callable = FirebaseFunctions.instance.httpsCallable(
      functionName,
      options: HttpsCallableOptions(timeout: timeout),
    );
    final result = await callable.call<Object?>(payload);
    return result.data;
  }

  // Identical requests that overlap share one server call, so a double tap or two handlers
  // firing for one action cost a single rate-limited request.
  static final Map<String, Future<http.Response>> _inFlight = {};

  @visibleForTesting
  static int get inFlightCount => _inFlight.length;

  static Future<http.Response> generate({
    required GeminiFeature feature,
    required Map<String, dynamic> request,
    String? model,
    Duration timeout = const Duration(seconds: 55),
  }) {
    final payload = <String, dynamic>{
      'feature': feature.wireName,
      if (model != null) 'model': model,
      'request': request,
    };
    final String key;
    try {
      key = jsonEncode(payload);
    } catch (_) {
      return _send(feature, payload, timeout);
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final call = _send(feature, payload, timeout);
    _inFlight[key] = call;
    call.whenComplete(() => _inFlight.remove(key));
    return call;
  }

  static Future<http.Response> _send(GeminiFeature feature, Map<String, dynamic> payload, Duration timeout) async {
    try {
      final data = await _invoke(payload, timeout).timeout(timeout);
      return http.Response(jsonEncode(data), 200, headers: _jsonHeaders);
    } on FirebaseFunctionsException catch (error) {
      return _failure(statusForCode(error.code), error.message ?? error.code);
    } on TimeoutException {
      return _failure(504, 'deadline-exceeded');
    } catch (error) {
      debugPrint('GeminiGateway ${feature.wireName} failed: ${error.runtimeType}');
      return _failure(503, 'unavailable');
    }
  }

  static const Map<String, String> _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  static http.Response _failure(int status, String message) => http.Response(
        jsonEncode({
          'error': {'code': status, 'message': message}
        }),
        status,
        headers: _jsonHeaders,
      );

  @visibleForTesting
  static int statusForCode(String code) {
    switch (code) {
      case 'invalid-argument':
        return 400;
      case 'unauthenticated':
        return 401;
      case 'permission-denied':
        return 403;
      case 'resource-exhausted':
        return 429;
      case 'deadline-exceeded':
        return 504;
      default:
        return 503;
    }
  }
}
