class LeaseExpirationRiskItem {
  final String propertyId;
  final Map<String, String> propertyTitle;
  final String tenantName;
  final DateTime expirationDate;
  final int daysRemaining;
  final double currentMonthlyRent;
  final double renewalProbability; // e.g. 0.85 (85%)
  final Map<String, String> actionRecommendation;

  const LeaseExpirationRiskItem({
    required this.propertyId,
    required this.propertyTitle,
    required this.tenantName,
    required this.expirationDate,
    required this.daysRemaining,
    required this.currentMonthlyRent,
    required this.renewalProbability,
    required this.actionRecommendation,
  });

  String getTitle(String lang) =>
      propertyTitle[lang] ?? propertyTitle['en'] ?? '';
  String getRecommendation(String lang) =>
      actionRecommendation[lang] ?? actionRecommendation['en'] ?? '';
}

class StrategicGrowthRecommendationItem {
  final String titleAr;
  final String titleEn;
  final String titleHi;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionHi;
  final String targetRegion;
  final double projectedRoiPercentage; // e.g. 9.4%
  final String estimatedCapitalRequired;
  final String urgencyLevel; // 'high', 'medium', 'strategic'

  const StrategicGrowthRecommendationItem({
    required this.titleAr,
    required this.titleEn,
    required this.titleHi,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.targetRegion,
    required this.projectedRoiPercentage,
    required this.estimatedCapitalRequired,
    this.urgencyLevel = 'strategic',
  });

  String getTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'hi') return titleHi;
    return titleEn;
  }

  String getDescription(String lang) {
    if (lang == 'ar') return descriptionAr;
    if (lang == 'hi') return descriptionHi;
    return descriptionEn;
  }
}

class MonthlyFinancialTrendItem {
  final String monthLabelAr;
  final String monthLabelEn;
  final String monthLabelHi;
  final double grossIncome;
  final double expenses;
  final double netIncome;

  const MonthlyFinancialTrendItem({
    required this.monthLabelAr,
    required this.monthLabelEn,
    required this.monthLabelHi,
    required this.grossIncome,
    required this.expenses,
    required this.netIncome,
  });

  String getMonthLabel(String lang) {
    if (lang == 'ar') return monthLabelAr;
    if (lang == 'hi') return monthLabelHi;
    return monthLabelEn;
  }
}

class ExecutiveFinancialReport {
  final String reportId;
  final DateTime generatedAt;
  final String periodLabel; // e.g. "Q3 2026"
  final String countryCode; // 'EG' or 'AE'
  final String currencyCode; // 'EGP' or 'AED'

  // High-Level Financial Performance Metrics
  final double totalPortfolioValuation;
  final double grossRentalIncome;
  final double operatingExpenses;
  final double netOperatingIncome; // NOI
  final double capRatePercentage; // Cap Rate e.g. 8.8%
  final double cashOnCashReturnPercentage; // e.g. 11.2%
  final double occupancyRatePercentage; // e.g. 96.5%
  final double rentCollectionEfficiencyPercentage; // e.g. 99.4%
  final int totalManagedUnits;
  final int activeLeasesCount;

  // AI Structured Executive Narratives (Gemini Pro)
  final Map<String, String> executiveSummary;
  final Map<String, String> cashFlowOutlook;
  final List<LeaseExpirationRiskItem> leaseExpirationRisks;
  final List<StrategicGrowthRecommendationItem> strategicGrowthRecommendations;
  final List<MonthlyFinancialTrendItem> monthlyTrends;

  const ExecutiveFinancialReport({
    required this.reportId,
    required this.generatedAt,
    required this.periodLabel,
    required this.countryCode,
    required this.currencyCode,
    required this.totalPortfolioValuation,
    required this.grossRentalIncome,
    required this.operatingExpenses,
    required this.netOperatingIncome,
    required this.capRatePercentage,
    required this.cashOnCashReturnPercentage,
    required this.occupancyRatePercentage,
    required this.rentCollectionEfficiencyPercentage,
    required this.totalManagedUnits,
    required this.activeLeasesCount,
    required this.executiveSummary,
    required this.cashFlowOutlook,
    required this.leaseExpirationRisks,
    required this.strategicGrowthRecommendations,
    required this.monthlyTrends,
  });

  String getExecutiveSummary(String lang) =>
      executiveSummary[lang] ?? executiveSummary['en'] ?? '';
  String getCashFlowOutlook(String lang) =>
      cashFlowOutlook[lang] ?? cashFlowOutlook['en'] ?? '';
}
