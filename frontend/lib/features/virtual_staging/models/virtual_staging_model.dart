enum VirtualStagingStyle {
  modernLuxury,
  classicArabesque,
  scandinavian,
  minimalistExecutive,
  coastalMarine,
}

enum StagingRoomType {
  livingRoom,
  masterBedroom,
  diningRoom,
  homeOffice,
  balconyTerrace,
}

class VirtualStagingPair {
  final String id;
  final String originalEmptyImageUrl;
  final String stagedImageUrl;
  final VirtualStagingStyle style;
  final StagingRoomType roomType;
  final Map<String, String> styleName;
  final Map<String, String> styleDescription;
  final List<String> furnitureElementsAr;
  final List<String> furnitureElementsEn;
  final List<String> furnitureElementsHi;
  final double renderingConfidence; // e.g. 0.994
  final int renderingTimeMs; // e.g. 850ms

  const VirtualStagingPair({
    required this.id,
    required this.originalEmptyImageUrl,
    required this.stagedImageUrl,
    required this.style,
    required this.roomType,
    required this.styleName,
    required this.styleDescription,
    required this.furnitureElementsAr,
    required this.furnitureElementsEn,
    required this.furnitureElementsHi,
    this.renderingConfidence = 0.992,
    this.renderingTimeMs = 820,
  });

  String getStyleName(String lang) => styleName[lang] ?? styleName['en'] ?? '';
  String getDescription(String lang) =>
      styleDescription[lang] ?? styleDescription['en'] ?? '';

  List<String> getFurnitureElements(String lang) {
    if (lang == 'ar') return furnitureElementsAr;
    if (lang == 'hi') return furnitureElementsHi;
    return furnitureElementsEn;
  }
}

class VirtualStagingStylePreset {
  final VirtualStagingStyle style;
  final Map<String, String> name;
  final Map<String, String> description;
  final String iconEmoji;
  final String sampleThumbnailUrl;

  const VirtualStagingStylePreset({
    required this.style,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.sampleThumbnailUrl,
  });

  String getName(String lang) => name[lang] ?? name['en'] ?? '';
  String getDescription(String lang) => description[lang] ?? description['en'] ?? '';
}
