enum MarketDemandStatus {
  highDemand,
  moderateDemand,
  coolingDown,
}

enum MarketState {
  sellersMarket, // سوق لصالح الملاك (الطلب يفوق المعروض)
  buyersMarket,  // سوق لصالح المستأجرين/المشترين (المعروض يفوق الطلب)
  balancedMarket // سوق متوازن ومستقر
}

enum PriceTrendDirection {
  risingFast,
  risingModerate,
  stable,
  correctingDown,
}

class DistrictMarketData {
  final String id;
  final Map<String, String> name;
  final Map<String, String> city;
  final int demandVelocityDays; // Average days on market before being rented
  final double averageRentPerSqm;
  final double annualRentalYield;
  final PriceTrendDirection priceTrend;
  final int demandIndexScore; // 0 to 100
  final double priceGrowthRateMoM; // e.g. +3.4%
  final String countryCode; // 'EG' or 'AE'

  const DistrictMarketData({
    required this.id,
    required this.name,
    required this.city,
    required this.demandVelocityDays,
    required this.averageRentPerSqm,
    required this.annualRentalYield,
    required this.priceTrend,
    required this.demandIndexScore,
    required this.priceGrowthRateMoM,
    required this.countryCode,
  });
}

class MarketHistoricalPoint {
  final String monthLabel; // e.g. "يونيو 2026" or "Jun 2026"
  final Map<String, String> localizedMonth;
  final int indexPoints;
  final double demandPercentage;
  final double? momGrowth; // e.g. +3.2%
  final String? year; // e.g. "2026"

  const MarketHistoricalPoint({
    required this.monthLabel,
    required this.localizedMonth,
    required this.indexPoints,
    required this.demandPercentage,
    this.momGrowth,
    this.year,
  });
}

class MarketKeyDriver {
  final Map<String, String> title;
  final Map<String, String> impactDescription;
  final bool isPositiveImpact;
  final String metricBadge;

  const MarketKeyDriver({
    required this.title,
    required this.impactDescription,
    required this.isPositiveImpact,
    required this.metricBadge,
  });
}

class DailyMarketSignal {
  final Map<String, String> headline;
  final String category; // 'demand', 'economy', 'policy', 'investment'
  final String impact; // 'positive', 'neutral', 'alert'
  final String sourceName;
  final String? sourceUrl;
  final Map<String, String> timeAgo;

  const DailyMarketSignal({
    required this.headline,
    required this.category,
    required this.impact,
    required this.sourceName,
    this.sourceUrl,
    required this.timeAgo,
  });
}

class MarketIndexSummary {
  final String countryCode; // 'EG' or 'AE'
  final String indexName; // e.g. "مؤشر عقارماب مصر" or "مؤشر دبي للعقارات DXB"
  final int indexPoints; // e.g. 2940 pts
  final double indexChangeMoM; // e.g. +4.2%
  final MarketDemandStatus demandStatus;
  final MarketState marketState;
  final double averageRentalGrowthYoY;
  final double averageDaysOnMarket;
  final double inflationHedgingScore; // e.g. 9.4 / 10
  final Map<String, String> aiExecutiveSummary;
  final Map<String, String> ownerAdvice;
  final Map<String, String> tenantAdvice;
  final List<MarketKeyDriver> keyDrivers;
  final List<DistrictMarketData> topDistricts;
  final List<MarketHistoricalPoint> historicalTrend;
  final String lastUpdatedTimestamp;
  final List<DailyMarketSignal> dailySignals;
  final List<String> verifiedSources;
  final String dailyBriefingTime;
  final bool isLiveGrounded;

  const MarketIndexSummary({
    required this.countryCode,
    required this.indexName,
    required this.indexPoints,
    required this.indexChangeMoM,
    required this.demandStatus,
    required this.marketState,
    required this.averageRentalGrowthYoY,
    required this.averageDaysOnMarket,
    required this.inflationHedgingScore,
    required this.aiExecutiveSummary,
    required this.ownerAdvice,
    required this.tenantAdvice,
    required this.keyDrivers,
    required this.topDistricts,
    required this.historicalTrend,
    required this.lastUpdatedTimestamp,
    this.dailySignals = const [],
    this.verifiedSources = const [],
    this.dailyBriefingTime = '09:00 ص',
    this.isLiveGrounded = true,
  });
}
