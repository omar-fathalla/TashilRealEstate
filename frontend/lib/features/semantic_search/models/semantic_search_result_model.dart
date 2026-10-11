import 'package:flutter/foundation.dart';
import '../../public_marketplace/models/property_item.dart';

@immutable
class SemanticSearchResultItem {
  final PropertyItem property;
  final double similarityScore; // 0.0 to 1.0 (e.g. 0.984 -> 98.4%)
  final String matchReasonAr;
  final String matchReasonEn;
  final String matchReasonHi;
  final List<String> matchedFeaturesAr;
  final List<String> matchedFeaturesEn;
  final List<String> matchedFeaturesHi;
  final String? visualStyle;

  const SemanticSearchResultItem({
    required this.property,
    required this.similarityScore,
    required this.matchReasonAr,
    required this.matchReasonEn,
    required this.matchReasonHi,
    required this.matchedFeaturesAr,
    required this.matchedFeaturesEn,
    required this.matchedFeaturesHi,
    this.visualStyle,
  });

  String getMatchReason(String lang) {
    if (lang == 'en') return matchReasonEn;
    if (lang == 'hi') return matchReasonHi;
    return matchReasonAr;
  }

  List<String> getMatchedFeatures(String lang) {
    if (lang == 'en') return matchedFeaturesEn;
    if (lang == 'hi') return matchedFeaturesHi;
    return matchedFeaturesAr;
  }
}
