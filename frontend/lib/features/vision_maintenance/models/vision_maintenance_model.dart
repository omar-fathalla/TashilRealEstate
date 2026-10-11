enum MaintenanceIssueCategory {
  plumbing,
  hvac,
  electrical,
  civilFinishes,
  appliances,
  locksSecurity,
}

enum MaintenanceUrgencyLevel {
  critical, // 🚨 طارئ (تسريب مياه رئيسي، ماس كهربائي)
  high,     // عالي (توقف التكييف بالكامل في الصيف)
  medium,   // متوسط (تلف مقبض، تسريب خفيف)
  low,      // عادي (دهان سطحي)
}

class MaintenanceVisualSample {
  final String id;
  final String photoUrl;
  final Map<String, String> title;
  final MaintenanceIssueCategory category;
  final MaintenanceUrgencyLevel urgency;

  const MaintenanceVisualSample({
    required this.id,
    required this.photoUrl,
    required this.title,
    required this.category,
    required this.urgency,
  });

  String getTitle(String lang) => title[lang] ?? title['en'] ?? '';
}

class VisionMaintenanceDiagnosisResult {
  final String issueId;
  final String photoUrl;
  final DateTime diagnosedAt;
  final MaintenanceIssueCategory category;
  final MaintenanceUrgencyLevel urgency;
  final double confidenceScore; // e.g. 0.994
  final Map<String, String> detectedProblemTitle;
  final Map<String, String> rootCauseAnalysis;
  final List<String> recommendedActionStepsAr;
  final List<String> recommendedActionStepsEn;
  final List<String> recommendedActionStepsHi;
  final List<String> requiredSparePartsAr;
  final List<String> requiredSparePartsEn;
  final List<String> requiredSparePartsHi;
  final double estimatedCostMin;
  final double estimatedCostMax;
  final String currencyCode; // 'EGP' or 'AED'
  final Map<String, String> assignedTechnicianType;
  final bool isSafetyHazard;

  const VisionMaintenanceDiagnosisResult({
    required this.issueId,
    required this.photoUrl,
    required this.diagnosedAt,
    required this.category,
    required this.urgency,
    required this.confidenceScore,
    required this.detectedProblemTitle,
    required this.rootCauseAnalysis,
    required this.recommendedActionStepsAr,
    required this.recommendedActionStepsEn,
    required this.recommendedActionStepsHi,
    required this.requiredSparePartsAr,
    required this.requiredSparePartsEn,
    required this.requiredSparePartsHi,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.currencyCode,
    required this.assignedTechnicianType,
    this.isSafetyHazard = false,
  });

  String getTitle(String lang) =>
      detectedProblemTitle[lang] ?? detectedProblemTitle['en'] ?? '';
  String getRootCause(String lang) =>
      rootCauseAnalysis[lang] ?? rootCauseAnalysis['en'] ?? '';
  String getTechnicianType(String lang) =>
      assignedTechnicianType[lang] ?? assignedTechnicianType['en'] ?? '';

  List<String> getActionSteps(String lang) {
    if (lang == 'ar') return recommendedActionStepsAr;
    if (lang == 'hi') return recommendedActionStepsHi;
    return recommendedActionStepsEn;
  }

  List<String> getSpareParts(String lang) {
    if (lang == 'ar') return requiredSparePartsAr;
    if (lang == 'hi') return requiredSparePartsHi;
    return requiredSparePartsEn;
  }
}
