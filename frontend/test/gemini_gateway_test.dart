import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/ai_quota_manager.dart';
import 'package:tashil_real_estate/core/services/gemini_ai_service.dart';
import 'package:tashil_real_estate/core/services/gemini_gateway.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';
import 'package:tashil_real_estate/features/document_ocr/models/document_ocr_result_model.dart';
import 'package:tashil_real_estate/features/document_ocr/services/ai_document_ocr_service.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/services/gemini_onboarding_service.dart';
import 'package:tashil_real_estate/features/image_moderation/services/ai_image_moderation_service.dart';
import 'package:tashil_real_estate/features/legal_ai_advisor/services/ai_legal_advisor_service.dart';
import 'package:tashil_real_estate/features/market_index/services/ai_market_index_service.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/semantic_search/services/ai_semantic_vector_search_service.dart';
import 'package:tashil_real_estate/features/voice_broker/services/gemini_live_voice_broker_service.dart';

void main() {
  final calls = <Map<String, dynamic>>[];

  Map<String, dynamic> geminiText(String text) => {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': text}
              ]
            }
          }
        ],
      };

  setUp(() {
    calls.clear();
    AiQuotaManager().resetForTesting();
    GeminiGateway.callOverride = (payload) async {
      calls.add(payload);
      return geminiText('{}');
    };
  });

  tearDown(() => GeminiGateway.callOverride = null);

  group('GeminiGateway', () {
    test('sends the feature, model and request to the geminiGenerate callable', () async {
      final response = await GeminiGateway.generate(
        feature: GeminiFeature.marketIndex,
        model: 'gemini-2.5-flash',
        request: {
          'contents': [
            {
              'parts': [
                {'text': 'hi'}
              ]
            }
          ]
        },
      );
      expect(GeminiGateway.functionName, 'geminiGenerate');
      expect(calls.single, {
        'feature': 'market_index',
        'model': 'gemini-2.5-flash',
        'request': {
          'contents': [
            {
              'parts': [
                {'text': 'hi'}
              ]
            }
          ]
        },
      });
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'], '{}');
    });

    test('feature names match the server allowlist', () {
      expect(GeminiFeature.values.map((f) => f.wireName).toSet(), {
        'valuation',
        'geocoding',
        'market_index',
        'image_moderation',
        'voice_broker',
        'semantic_search',
        'legal_advisor',
        'onboarding',
        'document_ocr',
      });
    });

    test('callable errors become HTTP-style statuses instead of throwing', () async {
      expect(GeminiGateway.statusForCode('resource-exhausted'), 429);
      expect(GeminiGateway.statusForCode('unauthenticated'), 401);
      expect(GeminiGateway.statusForCode('invalid-argument'), 400);
      expect(GeminiGateway.statusForCode('deadline-exceeded'), 504);
      expect(GeminiGateway.statusForCode('internal'), 503);

      GeminiGateway.callOverride = (_) async => throw StateError('no Firebase app');
      final failed = await GeminiGateway.generate(feature: GeminiFeature.valuation, request: {'contents': []});
      expect(failed.statusCode, 503);
      expect(jsonDecode(failed.body)['error']['message'], 'unavailable');
    });

    testWidgets('a callable that never answers times out as 504', (tester) async {
      GeminiGateway.callOverride = (_) => Completer<Object?>().future;
      late int status;
      unawaited(GeminiGateway.generate(
        feature: GeminiFeature.valuation,
        request: {'contents': []},
        timeout: const Duration(seconds: 2),
      ).then((r) => status = r.statusCode));
      await tester.pump(const Duration(seconds: 3));
      expect(status, 504);
    });
  });

  group('every Gemini feature goes through GeminiGateway', () {
    final property = PropertyItem(
      id: 'p1',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: const {'ar': 'شقة', 'en': 'Flat', 'hi': 'फ्लैट'},
      descriptions: const {'ar': 'وصف', 'en': 'Desc', 'hi': 'विवरण'},
      propertyTypeCode: 'apartment',
      locations: const {'ar': 'القاهرة', 'en': 'Cairo', 'hi': 'काहिरा'},
      cityCode: 'new_cairo',
      pricePerMonth: 20000,
      bedrooms: 2,
      bathrooms: 1,
      areaSqM: 120,
      imageUrls: const [],
      amenitiesMap: const {'ar': [], 'en': [], 'hi': []},
      isFurnished: false,
      isFeatured: false,
      agencyNames: const {'ar': 'تسهيل', 'en': 'Tashil', 'hi': 'तशिल'},
      agencyPhone: '+20 100 000 0000',
      rating: 4.5,
    );

    Future<void> expectFeature(WidgetTester tester, GeminiFeature feature, Future<Object?> Function() run) async {
      await tester.runAsync(run);
      expect(calls.map((c) => c['feature']), contains(feature.wireName));
      final payload = calls.firstWhere((c) => c['feature'] == feature.wireName);
      final request = payload['request'] as Map<String, dynamic>;
      expect(request['contents'], isA<List<dynamic>>());
      expect(jsonEncode(payload), isNot(contains('key=')));
    }

    testWidgets('smart valuation', (tester) async {
      await expectFeature(tester, GeminiFeature.valuation, () => GeminiAiService().estimateRentalValue(
            countryCode: 'EG',
            cityOrArea: 'New Cairo',
            propertyType: 'apartment',
            areaSqm: 120,
            bedrooms: 2,
            bathrooms: 1,
            finishingType: 'luxury',
            isFurnished: false,
            specialAmenities: const [],
            langCode: 'en',
          ));
    });

    testWidgets('address geocoding fallback', (tester) async {
      await expectFeature(tester, GeminiFeature.geocoding,
          () => LocationGeocodingService().verifyAndCorrectAddress('zzqx unknown lane 77', countryCode: 'EG'));
    });

    testWidgets('market analyst', (tester) async {
      await expectFeature(tester, GeminiFeature.marketIndex,
          () => AiMarketIndexService().askMarketAnalyst(userQuery: 'Is rent rising?', countryCode: 'AE', langCode: 'en'));
    });

    testWidgets('image moderation sends the photo inline', (tester) async {
      await expectFeature(tester, GeminiFeature.imageModeration,
          () => AiImageModerationService().moderateImage(fileName: 'a.jpg', imageBytes: Uint8List.fromList([1, 2, 3])));
      final parts = (calls.single['request']['contents'] as List).first['parts'] as List;
      expect(parts.any((p) => (p as Map).containsKey('inline_data') || p.containsKey('inlineData')), isTrue);
    });

    testWidgets('voice broker', (tester) async {
      await expectFeature(tester, GeminiFeature.voiceBroker, () => GeminiLiveVoiceBrokerService().processUserSpeech(
            userSpeechText: 'Can I see it tomorrow?',
            property: property,
            dialect: VoiceBrokerDialect.english,
            conversationHistory: const [],
          ));
    });

    testWidgets('semantic search', (tester) async {
      await expectFeature(tester, GeminiFeature.semanticSearch,
          () => AiSemanticVectorSearchService().searchByNaturalLanguage(query: 'quiet flat near a park', countryCode: 'EG'));
    });

    testWidgets('legal clause advisor', (tester) async {
      await expectFeature(tester, GeminiFeature.legalAdvisor,
          () => AiLegalAdvisorService().auditAndRefineClause(clauseDraft: 'Rent is due monthly.', countryCode: 'AE'));
    });

    testWidgets('fast onboarding: voice parsing and marketing copy', (tester) async {
      await expectFeature(tester, GeminiFeature.onboarding, () => GeminiOnboardingService().parseVoiceTranscriptionToDraft(
            voiceTranscription: 'Two bedroom flat in Maadi for 15000',
            countryCode: 'EG',
          ));
      await tester.runAsync(() => GeminiOnboardingService().generateMarketingDescriptions(
            draft: FastPropertyDraft(),
            tone: PropertyMarketingTone.cozyFamily,
          ));
      expect(calls.where((c) => c['feature'] == 'onboarding'), hasLength(2));
    });

    testWidgets('document OCR sends the scan inline', (tester) async {
      await expectFeature(tester, GeminiFeature.documentOcr, () => AiDocumentOcrService().processDocumentOcr(
            docType: DocumentOcrType.emiratesId,
            countryCode: 'AE',
            rawBytes: Uint8List.fromList([1, 2, 3]),
          ));
      final parts = (calls.single['request']['contents'] as List).first['parts'] as List;
      expect(parts.any((p) => (p as Map).containsKey('inline_data') || p.containsKey('inlineData')), isTrue);
    });
  });
}
