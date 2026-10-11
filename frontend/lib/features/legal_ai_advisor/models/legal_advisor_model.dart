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
  final String applicableLawReferenceAr;
  final String applicableLawReferenceEn;
  final String applicableLawReferenceHi;
  final String legalReasoningAr;
  final String legalReasoningEn;
  final String legalReasoningHi;
  final String suggestedBalancedClauseAr;
  final String suggestedBalancedClauseEn;
  final String suggestedBalancedClauseHi;

  const LegalClauseAuditResult({
    required this.clauseId,
    required this.originalDraftText,
    required this.riskLevel,
    required this.legalValidityScore,
    required this.applicableLawReferenceAr,
    required this.applicableLawReferenceEn,
    required this.applicableLawReferenceHi,
    required this.legalReasoningAr,
    required this.legalReasoningEn,
    required this.legalReasoningHi,
    required this.suggestedBalancedClauseAr,
    required this.suggestedBalancedClauseEn,
    required this.suggestedBalancedClauseHi,
  });

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
}
