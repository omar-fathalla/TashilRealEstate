import '../../lease_builder/models/lease_contract_model.dart';

enum LegalComplianceRiskLevel {
  compliant,      // 🟢 متوافق قانونياً 100%
  needsAdjustment,// 🟡 يحتاج تعديل صياغة
  invalidVoid,    // 🔴 باطل قانونياً / مخالف للنظام العام
}

class LegalClauseAuditResult {
  final String clauseId;
  final String originalDraftText;
  final LegalComplianceRiskLevel riskLevel;
  final double legalValidityScore; // e.g. 0.985
  final String clauseTitleAr;
  final String clauseTitleEn;
  final String clauseTitleHi;
  final String applicableLawReferenceAr;
  final String applicableLawReferenceEn;
  final String applicableLawReferenceHi;
  final String legalReasoningAr;
  final String legalReasoningEn;
  final String legalReasoningHi;
  final String suggestedBalancedClauseAr;
  final String suggestedBalancedClauseEn;
  final String suggestedBalancedClauseHi;
  final bool isGrounded;
  final List<String> groundingSources;
  final List<String> searchQueries;

  const LegalClauseAuditResult({
    required this.clauseId,
    required this.originalDraftText,
    required this.riskLevel,
    required this.legalValidityScore,
    this.clauseTitleAr = 'بند قانوني مدقق بالذكاء الاصطناعي',
    this.clauseTitleEn = 'AI Audited Legal Clause',
    this.clauseTitleHi = 'एआई ऑडिटेड कानूनी खंड',
    required this.applicableLawReferenceAr,
    required this.applicableLawReferenceEn,
    required this.applicableLawReferenceHi,
    required this.legalReasoningAr,
    required this.legalReasoningEn,
    required this.legalReasoningHi,
    required this.suggestedBalancedClauseAr,
    required this.suggestedBalancedClauseEn,
    required this.suggestedBalancedClauseHi,
    this.isGrounded = false,
    this.groundingSources = const [],
    this.searchQueries = const [],
  });

  String getTitle(String lang) {
    if (lang == 'ar') return clauseTitleAr;
    if (lang == 'hi') return clauseTitleHi;
    return clauseTitleEn;
  }

  String getLawReference(String lang) {
    if (lang == 'ar') return applicableLawReferenceAr;
    if (lang == 'hi') return applicableLawReferenceHi;
    return applicableLawReferenceEn;
  }

  String getReasoning(String lang) {
    if (lang == 'ar') return legalReasoningAr;
    if (lang == 'hi') return legalReasoningHi;
    return legalReasoningEn;
  }

  String getSuggestedClause(String lang) {
    if (lang == 'ar') return suggestedBalancedClauseAr;
    if (lang == 'hi') return suggestedBalancedClauseHi;
    return suggestedBalancedClauseEn;
  }

  LegalClause toLegalClause({String? customId}) {
    return LegalClause(
      id: customId ?? 'ai_clause_${DateTime.now().millisecondsSinceEpoch}',
      titleAr: clauseTitleAr.isNotEmpty ? clauseTitleAr : 'بند قانوني مدقق بالذكاء الاصطناعي',
      titleEn: clauseTitleEn.isNotEmpty ? clauseTitleEn : 'AI Audited Legal Clause',
      titleHi: clauseTitleHi.isNotEmpty ? clauseTitleHi : 'एआई ऑडिटेड कानूनी खंड',
      bodyAr: suggestedBalancedClauseAr,
      bodyEn: suggestedBalancedClauseEn,
      bodyHi: suggestedBalancedClauseHi,
      isMandatory: false,
      isEnabled: true,
      lawReference: applicableLawReferenceAr,
    );
  }
}
