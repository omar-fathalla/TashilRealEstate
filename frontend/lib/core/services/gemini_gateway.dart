import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

/// Calls Gemini through Cloud Functions. The API key never reaches the client.
class GeminiGateway {
  static Future<http.Response> generate({
    required String model,
    required Map<String, dynamic> body,
    String purpose = 'text',
    bool processingConsent = false,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'geminiGenerateContent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
      );
      final result = await callable.call(<String, dynamic>{
        'model': model,
        'purpose': purpose,
        'processingConsent': processingConsent,
        'body': body,
      });
      final data = result.data;
      return http.Response(jsonEncode(data), 200);
    } on FirebaseFunctionsException catch (error) {
      final code = error.code == 'resource-exhausted' ? 429 : 400;
      return http.Response(
        jsonEncode({'error': {'message': error.message ?? 'AI request failed'}}),
        code,
      );
    }
  }
}
