import '../../investor_dashboard/models/investor_portfolio_model.dart';

enum PricingSeasonType {
  tourismPeak,
  academicSurge,
  summerCoast,
  shoulderOffPeak,
}

class MonthlyPriceForecast {
  final String monthKey; // e.g. "2026-09"
  final Map<String, String> monthName;
  final double basePrice;
  final double recommendedPrice;
  final double highSurgePrice;
  final double floorPrice;
  final double occupancyRatePct;
  final PricingSeasonType seasonType;

  const MonthlyPriceForecast({
    required this.monthKey,
    required this.monthName,
    required this.basePrice,
    required this.recommendedPrice,
    required this.highSurgePrice,
    required this.floorPrice,
    required this.occupancyRatePct,
    required this.seasonType,
  });

  String getMonthName(String lang) => monthName[lang] ?? monthName['en'] ?? monthKey;
}

class AssetDynamicPricingItem {
  final PortfolioAssetItem asset;
  final double currentBaseRent;
  final double recommendedDynamicRent;
  final double originalBaseRent;
  final double dynamicMultiplier; // e.g. 1.18x (+18%)
  final double projectedAnnualNetGain; // in currency amount
  final double projectedYieldIncreasePct; // e.g. +1.8% (from 7.2% to 9.0%)
  final int projectedVacancyReductionDays; // e.g. 35 days saved
  final PricingSeasonType currentSeasonType;
  final Map<String, String> strategyRecommendation;
  final List<String> demandDriversAr;
  final List<String> demandDriversEn;
  final List<String> demandDriversHi;
  final List<MonthlyPriceForecast> monthlyForecastCurve;
  bool isAutoPilotEnabled;
  final bool isApplied;

  AssetDynamicPricingItem({
    required this.asset,
    required this.currentBaseRent,
    required this.recommendedDynamicRent,
    double? originalBaseRent,
    required this.dynamicMultiplier,
    required this.projectedAnnualNetGain,
    required this.projectedYieldIncreasePct,
    required this.projectedVacancyReductionDays,
    required this.currentSeasonType,
    required this.strategyRecommendation,
    required this.demandDriversAr,
    required this.demandDriversEn,
    required this.demandDriversHi,
    required this.monthlyForecastCurve,
    this.isAutoPilotEnabled = false,
    this.isApplied = false,
  }) : originalBaseRent = originalBaseRent ?? currentBaseRent;

  String getStrategy(String lang) =>
      strategyRecommendation[lang] ??
      strategyRecommendation['en'] ??
      '';

  List<String> getDemandDrivers(String lang) {
    if (lang == 'ar') return demandDriversAr;
    if (lang == 'hi') return demandDriversHi;
    return demandDriversEn;
  }

  double get priceDiff => recommendedDynamicRent - currentBaseRent;
  double get priceDiffPercentage =>
      currentBaseRent > 0 ? (priceDiff / currentBaseRent) * 100 : 0;
}

class PortfolioYieldOptimizationSummary {
  final String countryCode;
  final int totalManagedAssets;
  final double totalCurrentAnnualRent;
  final double totalOptimizedAnnualRent;
  final double netAnnualRevenueGain;
  final double averageYieldIncreasePct; // e.g. +2.1%
  final int totalVacancyDaysSaved;
  final List<AssetDynamicPricingItem> assetRecommendations;

  const PortfolioYieldOptimizationSummary({
    required this.countryCode,
    required this.totalManagedAssets,
    required this.totalCurrentAnnualRent,
    required this.totalOptimizedAnnualRent,
    required this.netAnnualRevenueGain,
    required this.averageYieldIncreasePct,
    required this.totalVacancyDaysSaved,
    required this.assetRecommendations,
  });

  double get revenueIncreasePercentage => totalCurrentAnnualRent > 0
      ? (netAnnualRevenueGain / totalCurrentAnnualRent) * 100
      : 0;
}
