import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/legal_ai_advisor/models/legal_advisor_model.dart';
import 'package:tashil_real_estate/features/legal_ai_advisor/services/ai_legal_advisor_service.dart';
import 'package:tashil_real_estate/features/legal_ai_advisor/widgets/ai_legal_clause_advisor_dialog.dart';

Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [
      Locale('ar'),
      Locale('en'),
      Locale('hi'),
    ],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        primary: const Color(0xFF0F172A),
        secondary: const Color(0xFF3B82F6),
      ),
    ),
    home: Scaffold(
      body: Center(
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.currentLocale.value = const Locale('ar');
  });

  group('AI Legal Advisor Service & Statutory RAG Grounding Tests', () {
    final service = AiLegalAdvisorService();

    test('Auditing subleasing ("التاجير من الباطن") in Egypt (EG) cites Article 596 of Egyptian Civil Code', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'التاجير من الباطن',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.legalValidityScore, greaterThanOrEqualTo(0.99));
      expect(result.applicableLawReferenceAr, contains('596'));
      expect(result.applicableLawReferenceAr, contains('المدني المصري'));
      expect(result.legalReasoningAr, contains('المادة 596'));
      expect(result.legalReasoningAr, contains('باطن'));
      expect(result.suggestedBalancedClauseAr, contains('موافقة كتابية'));
      expect(result.isGrounded, isTrue);

      final clause = result.toLegalClause();
      expect(clause.titleAr, contains('التأجير من الباطن'));
      expect(clause.isEnabled, isTrue);
      expect(clause.isMandatory, isFalse);
      expect(clause.lawReference, contains('596'));
    });

    test('Auditing subleasing ("التأجير من الباطن") in UAE (AE) cites Articles 24 & 25 of Dubai Law 26/2007', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'التأجير من الباطن والتنازل',
        countryCode: 'AE',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.applicableLawReferenceAr, contains('24'));
      expect(result.applicableLawReferenceAr, contains('26 لسنة 2007'));
      expect(result.legalReasoningAr, contains('دبي'));
      expect(result.suggestedBalancedClauseAr, contains('موافقة خطية'));
      expect(result.isGrounded, isTrue);
    });

    test('Auditing maintenance ("الصيانة والترميم") in Egypt cites Articles 564-567 of Civil Code', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'الصيانة والترميم والأعطال',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.applicableLawReferenceAr, contains('564'));
      expect(result.legalReasoningAr, contains('الترميمات الضرورية'));
      expect(result.suggestedBalancedClauseAr, contains('المؤجر'));
    });

    test('Auditing late payment penalty ("غرامة تأخير السداد") in Egypt cites Article 158 (Explicit Forfeiture)', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'غرامة تأخير سداد الإيجار والفسخ',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.applicableLawReferenceAr, contains('158'));
      expect(result.legalReasoningAr, contains('الشرط الفاسخ'));
    });

    test('Auditing pet policy ("تربية الحيوانات الأليفة") yields valid building regulation clause', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'تربية الكلاب والقطط والحيوانات الأليفة',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.clauseTitleAr, contains('الحيوانات الأليفة'));
      expect(result.suggestedBalancedClauseAr, contains('السكينة العامة'));
    });

    test('Auditing security deposit ("مبلغ التأمين") yields valid refund protocol clause', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'مبلغ التأمين واسترداده',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.clauseTitleAr, contains('التأمين'));
      expect(result.suggestedBalancedClauseAr, contains('محضر الاستلام'));
    });

    test('Auditing custom draft synthesizes dynamic legal clause in harmony with legislation', () async {
      final result = await service.auditAndRefineClause(
        clauseDraft: 'تركيب كاميرات مراقبة داخلية وخارجية في المدخل',
        countryCode: 'EG',
      );

      expect(result.riskLevel, LegalComplianceRiskLevel.compliant);
      expect(result.suggestedBalancedClauseAr, contains('كاميرات مراقبة'));
      expect(result.applicableLawReferenceAr, contains('القانون'));
    });
  });

  group('AI Legal Clause Advisor Dialog Widget Tests', () {
    testWidgets('Renders dialog with M3 shaded close button and audit button', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithApp(
          const AiLegalClauseAdvisorDialog(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المستشار القانوني العقاري الذكي'), findsOneWidget);
      expect(find.text('Google Search Grounded'), findsOneWidget);
      expect(find.text('Gemini 3.8 Flash Legal'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Entering "التاجير من الباطن" and auditing displays Article 596 and enables applying to lease', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      LegalClause? appliedClause;

      await tester.pumpWidget(
        wrapWithApp(
          AiLegalClauseAdvisorDialog(
            initialClauseText: 'التاجير من الباطن',
            onLegalClauseApplied: (clause) {
              appliedClause = clause;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify input text
      expect(find.text('التاجير من الباطن'), findsOneWidget);

      // Verify Article 596 appears in the result
      expect(find.textContaining('المادة 596'), findsWidgets);
      expect(find.textContaining('التأجير من الباطن'), findsWidgets);

      // Verify Apply Clause button exists
      final applyBtn = find.text('اعتماد وإضافة البند للعقد');
      expect(applyBtn, findsOneWidget);

      // Ensure button is visible in scroll view and tap
      await tester.ensureVisible(applyBtn);
      await tester.pumpAndSettle();
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(appliedClause, isNotNull);
      expect(appliedClause!.titleAr, contains('التأجير من الباطن'));
      expect(appliedClause!.bodyAr, contains('موافقة كتابية'));
      expect(appliedClause!.lawReference, contains('596'));
      expect(appliedClause!.isEnabled, isTrue);
    });

    testWidgets('Clicking quick assist chip populates draft and runs audit', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithApp(
          const AiLegalClauseAdvisorDialog(),
        ),
      );
      await tester.pumpAndSettle();

      // Find quick suggestion chip for subleasing
      final subleaseChip = find.text('التأجير من الباطن');
      expect(subleaseChip, findsWidgets);

      await tester.tap(subleaseChip.first);
      await tester.pumpAndSettle();

      // Result should display analysis for sublease
      expect(find.textContaining('596'), findsWidgets);
    });
  });
}
