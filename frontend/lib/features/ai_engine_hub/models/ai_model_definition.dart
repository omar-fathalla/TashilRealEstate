import 'package:flutter/material.dart';

/// Categories of AI tasks and services powering Tashil Real Estate
enum AiServiceType {
  /// Voice and text property specs extraction in Fast Onboarding
  propertyIngestion,

  /// Automated marketing copywriting, highlights, and listing descriptions
  marketingCopywriting,

  /// Real estate smart valuation, rental yield, and comp analysis (Zestimate)
  smartValuation,

  /// Semantic vector embeddings and hybrid multilingual property search
  semanticSearch,

  /// AI legal clause advisor, contract review, and dispute mitigation
  legalAdvisor,

  /// Room-preserving virtual staging, image moderation, and vision maintenance
  virtualStaging,
}

/// Token consumption & computational footprint rating
enum TokenConsumptionLevel {
  /// Highly optimized, sub-cent pricing, ultra-low token footprint
  ultraLow,

  /// Standard balanced token usage for creative generation and analysis
  balanced,

  /// High reasoning, extensive multi-step token generation, deeper inference
  high,
}

/// Definition of an AI model option available for switching
class AiModelOption {
  final String id;
  final String name;
  final String generationBadge;
  final String provider;
  final TokenConsumptionLevel tokenLevel;
  final int typicalTokensPerCall;
  final double inputCostPerMillion;
  final double outputCostPerMillion;
  final double averageLatencySeconds;
  final String contextWindow;
  final String badgeText;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionHi;
  final bool isRecommended;

  const AiModelOption({
    required this.id,
    required this.name,
    required this.generationBadge,
    required this.provider,
    required this.tokenLevel,
    required this.typicalTokensPerCall,
    required this.inputCostPerMillion,
    required this.outputCostPerMillion,
    required this.averageLatencySeconds,
    required this.contextWindow,
    required this.badgeText,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionHi,
    this.isRecommended = false,
  });

  /// Approximate total cost for 1,000 standard requests
  double get costPerThousandCalls {
    final inputShare = typicalTokensPerCall * 0.4;
    final outputShare = typicalTokensPerCall * 0.6;
    final cost = ((inputShare * inputCostPerMillion) + (outputShare * outputCostPerMillion)) / 1000000.0;
    return cost * 1000.0;
  }
}

/// A specific AI service card definition containing its top 3 latest switchable models
class AiServiceCategory {
  final AiServiceType serviceType;
  final String titleAr;
  final String titleEn;
  final String titleHi;
  final IconData icon;
  final String usedForAr;
  final String usedForEn;
  final String usedForHi;
  final String locationInAppAr;
  final String locationInAppEn;
  final String locationInAppHi;
  final String featureBadge;
  final List<AiModelOption> top3Models;

  const AiServiceCategory({
    required this.serviceType,
    required this.titleAr,
    required this.titleEn,
    required this.titleHi,
    required this.icon,
    required this.usedForAr,
    required this.usedForEn,
    required this.usedForHi,
    required this.locationInAppAr,
    required this.locationInAppEn,
    required this.locationInAppHi,
    required this.featureBadge,
    required this.top3Models,
  });
}
