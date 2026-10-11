class SmartValuationModel {
  final double estimatedRent;
  final double minRent;
  final double maxRent;
  final double pricePerSqm;
  final int confidenceScore;
  final String marketDemand;
  final String marketAnalysis;
  final List<ComparableUnit> comparableUnits;
  final List<String> optimizationTips;
  final String currency;
  final String countryCode;
  final bool isGrounded;
  final List<String> groundingSources;
  final List<String> searchQueries;
  final String? verifiedAddress;

  const SmartValuationModel({
    required this.estimatedRent,
    required this.minRent,
    required this.maxRent,
    required this.pricePerSqm,
    required this.confidenceScore,
    required this.marketDemand,
    required this.marketAnalysis,
    required this.comparableUnits,
    required this.optimizationTips,
    required this.currency,
    required this.countryCode,
    this.isGrounded = true,
    this.groundingSources = const ['Aqarmap', 'Property Finder'],
    this.searchQueries = const [],
    this.verifiedAddress,
  });

  factory SmartValuationModel.fromJson(Map<String, dynamic> json, String currency, String countryCode) {
    final sourcesList = (json['groundingSources'] as List?)?.map((s) => s.toString()).toList() ??
        (countryCode == 'AE'
            ? ['بيوت (Bayut)', 'بروبرتي فايندر (Property Finder)', 'دوبيزل (Dubizzle)', 'عقار ماب (Aqarmap)']
            : ['عقار ماب (Aqarmap)', 'بروبرتي فايندر (Property Finder)', 'دوبيزل (Dubizzle)', 'بيوت (Bayut)']);
    final queriesList = (json['searchQueries'] as List?)?.map((q) => q.toString()).toList() ?? [];

    return SmartValuationModel(
      estimatedRent: (json['estimatedRent'] as num?)?.toDouble() ?? 0.0,
      minRent: (json['minRent'] as num?)?.toDouble() ?? 0.0,
      maxRent: (json['maxRent'] as num?)?.toDouble() ?? 0.0,
      pricePerSqm: (json['pricePerSqm'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (json['confidenceScore'] as num?)?.toInt() ?? 92,
      marketDemand: json['marketDemand']?.toString() ?? 'high',
      marketAnalysis: json['marketAnalysis']?.toString() ?? '',
      comparableUnits: (json['comparableUnits'] as List?)
              ?.map((c) => ComparableUnit.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      optimizationTips: (json['optimizationTips'] as List?)
              ?.map((tip) => tip.toString())
              .toList() ??
          [],
      currency: currency,
      countryCode: countryCode,
      isGrounded: (json['isGrounded'] as bool?) ?? true,
      groundingSources: sourcesList,
      searchQueries: queriesList,
      verifiedAddress: json['verifiedAddress']?.toString(),
    );
  }
}

class ComparableUnit {
  final String title;
  final String location;
  final double rentPrice;
  final int areaSqm;
  final String sourcePortal;
  final bool isVerified;
  final String? sourceUrl;

  const ComparableUnit({
    required this.title,
    required this.location,
    required this.rentPrice,
    required this.areaSqm,
    this.sourcePortal = 'Aqarmap',
    this.isVerified = true,
    this.sourceUrl,
  });

  factory ComparableUnit.fromJson(Map<String, dynamic> json) {
    return ComparableUnit(
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0.0,
      areaSqm: (json['areaSqm'] as num?)?.toInt() ?? 0,
      sourcePortal: json['sourcePortal']?.toString() ?? 'Aqarmap',
      isVerified: (json['isVerified'] as bool?) ?? true,
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }
}

