import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/search/tashil_search.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/services/ai_quota_manager.dart';
import 'package:tashil_real_estate/core/services/gemini_gateway.dart';
import 'package:tashil_real_estate/features/public_marketplace/public_marketplace_screen.dart';
import 'package:tashil_real_estate/features/semantic_search/services/ai_semantic_vector_search_service.dart';

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true),
      home: home,
    );

Map<String, dynamic> _textRequest(String text) => {
      'contents': [
        {
          'parts': [
            {'text': text}
          ]
        }
      ]
    };

void main() {
  final calls = <Map<String, dynamic>>[];

  setUp(() {
    calls.clear();
    AiQuotaManager().resetForTesting();
    GeminiGateway.callOverride = (payload) async {
      calls.add(payload);
      return {'candidates': []};
    };
  });

  tearDown(() => GeminiGateway.callOverride = null);

  group('TAQ-73: one AI request per search', () {
    testWidgets('tapping an AI Smart Search suggestion in an empty field sends exactly one geminiGenerate call',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      CountryController.setCountry('EG');

      await tester.pumpWidget(_app(const PublicMarketplaceScreen()));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final bar = tester.widget<TashilSearchBar>(find.byType(TashilSearchBar));
      bar.onSplitMenuItemSelected!('ai');
      await tester.pump();

      await tester.tap(find.descendant(of: find.byType(TashilSearchBar), matching: find.byType(TextField)));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      const suggestion = 'شقة للبيع في الشيخ زايد';
      expect(find.text(suggestion), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text(suggestion));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      final searches = calls.where((c) => c['feature'] == 'semantic_search').toList();
      expect(searches, hasLength(1));
      expect(searches.single['request'].toString(), contains(suggestion));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('TashilSearchBar reports a suggestion tap through one handler only', (tester) async {
      final selected = <String>[];
      final submitted = <String>[];
      final controller = TextEditingController();

      Future<void> tapSuggestion({required bool withSelectHandler}) async {
        await tester.pumpWidget(_app(Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: TashilSearchBar(
                controller: controller,
                suggestions: const ['Studio in Downtown Dubai'],
                onSubmitted: submitted.add,
                onSelectSuggestion: withSelectHandler ? selected.add : null,
              ),
            ),
          ),
        )));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Studio in Downtown Dubai'));
        await tester.pumpAndSettle();
      }

      await tapSuggestion(withSelectHandler: true);
      expect(selected, ['Studio in Downtown Dubai']);
      expect(submitted, isEmpty);

      controller.clear();
      await tapSuggestion(withSelectHandler: false);
      expect(submitted, ['Studio in Downtown Dubai'], reason: 'without a select handler the tap still submits');
      expect(selected, hasLength(1));
    });

    test('identical overlapping requests share one server call; later or different requests do not', () async {
      final release = Completer<void>();
      GeminiGateway.callOverride = (payload) async {
        calls.add(payload);
        await release.future;
        return {'candidates': []};
      };

      final first = GeminiGateway.generate(feature: GeminiFeature.semanticSearch, request: _textRequest('villa'));
      final second = GeminiGateway.generate(feature: GeminiFeature.semanticSearch, request: _textRequest('villa'));
      final other = GeminiGateway.generate(feature: GeminiFeature.semanticSearch, request: _textRequest('studio'));
      expect(identical(first, second), isTrue);
      release.complete();
      final responses = await Future.wait([first, second, other]);
      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      expect(calls, hasLength(2));
      expect(GeminiGateway.inFlightCount, 0);

      await GeminiGateway.generate(feature: GeminiFeature.semanticSearch, request: _textRequest('villa'));
      expect(calls, hasLength(3), reason: 'a finished request is not cached');
    });

    test('two concurrent identical semantic searches reach the server once', () async {
      final release = Completer<void>();
      GeminiGateway.callOverride = (payload) async {
        calls.add(payload);
        await release.future;
        return {'candidates': []};
      };
      final service = AiSemanticVectorSearchService();
      final a = service.searchByNaturalLanguage(query: 'شقة للبيع في الشيخ زايد', countryCode: 'EG');
      final b = service.searchByNaturalLanguage(query: 'شقة للبيع في الشيخ زايد', countryCode: 'EG');
      release.complete();
      await Future.wait([a, b]);
      expect(calls, hasLength(1));
    });
  });
}
